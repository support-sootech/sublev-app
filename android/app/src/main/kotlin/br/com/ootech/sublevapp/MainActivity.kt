package br.com.ootech.sublevapp

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.IOException
import java.io.OutputStream
import java.util.UUID
import kotlinx.coroutines.* // Para coroutines

class MainActivity: FlutterActivity() {
    private val CHANNEL = "br.com.ootech.sublevapp" // Deve ser o mesmo do Flutter
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private val bluetoothAdapter: BluetoothAdapter? by lazy(LazyThreadSafetyMode.NONE) {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothManager.adapter
    }

    // UUID para Serial Port Profile (SPP), comum para impressoras Bluetooth
    private val PRINTER_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    // Coroutine scope
    private val job = Job()
    private val coroutineScope = CoroutineScope(Dispatchers.IO + job) // Usar Dispatchers.IO para operações de rede/bluetooth

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "connectBluetooth" -> {
                    val address = call.argument<String>("address")
                    if (address == null) {
                        result.error("INVALID_ARGUMENT", "Endereço não fornecido", null)
                        return@setMethodCallHandler
                    }
                    if (!hasBluetoothConnectPermission()) {
                         result.error("PERMISSION_DENIED", "Permissão BLUETOOTH_CONNECT não concedida", null)
                         return@setMethodCallHandler
                    }
                    coroutineScope.launch {
                        try {
                            connectToDevice(address)
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.error("CONNECTION_ERROR", "Falha ao conectar: ${e.message}", null) }
                        }
                    }
                }
                "disconnectBluetooth" -> {
                     coroutineScope.launch {
                        disconnectDevice()
                        withContext(Dispatchers.Main) { result.success(null) }
                    }
                }
                "printBluetoothData" -> {
                    val data = call.argument<ByteArray>("data")
                    if (data == null) {
                        result.error("INVALID_ARGUMENT", "Dados para impressão não fornecidos", null)
                        return@setMethodCallHandler
                    }
                     if (!hasBluetoothConnectPermission()) {
                         result.error("PERMISSION_DENIED", "Permissão BLUETOOTH_CONNECT não concedida", null)
                         return@setMethodCallHandler
                    }
                    coroutineScope.launch {
                        try {
                            sendDataToPrinter(data)
                            withContext(Dispatchers.Main) { result.success("Dados enviados para impressão") }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.error("PRINT_ERROR", "Falha ao imprimir: ${e.message}", null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        }
        // Para versões anteriores a S, BLUETOOTH e BLUETOOTH_ADMIN são suficientes e geralmente concedidas na instalação.
        // A lógica de runtime permission é mais crítica para S+
        return true // Simplificação para < S, mas idealmente você verificaria BLUETOOTH
    }


    @Throws(IOException::class, SecurityException::class)
    private fun connectToDevice(address: String) {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            throw IOException("Bluetooth não está habilitado ou não disponível.")
        }
        
        // Se já estiver conectado, desconecte primeiro (ou gerencie múltiplas conexões se necessário)
        disconnectDevice()

        val device: BluetoothDevice? = bluetoothAdapter!!.getRemoteDevice(address)
        if (device == null) {
            throw IOException("Dispositivo não encontrado com o endereço: $address")
        }

        // A permissão BLUETOOTH_CONNECT é verificada antes de chamar esta função
        bluetoothSocket = device.createRfcommSocketToServiceRecord(PRINTER_UUID)
        bluetoothSocket?.connect() // Esta é uma operação de bloqueio, por isso está em uma coroutine com Dispatchers.IO
        outputStream = bluetoothSocket?.outputStream
        if (outputStream == null) {
            throw IOException("Não foi possível obter o output stream.")
        }
    }

    @Throws(IOException::class)
    private fun sendDataToPrinter(data: ByteArray) {
        if (outputStream == null || bluetoothSocket == null || !bluetoothSocket!!.isConnected) {
            throw IOException("Impressora não conectada ou stream não disponível.")
        }
        outputStream?.write(data)
        outputStream?.flush()
    }

    private fun disconnectDevice() {
        try {
            outputStream?.close()
            bluetoothSocket?.close()
        } catch (e: IOException) {
            // Logar erro, mas não impedir a continuação
            println("Erro ao fechar socket/stream: ${e.message}")
        } finally {
            outputStream = null
            bluetoothSocket = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        coroutineScope.launch { disconnectDevice() } // Garante que desconecta
        job.cancel() // Cancela todas as coroutines quando a activity é destruída
    }
}

