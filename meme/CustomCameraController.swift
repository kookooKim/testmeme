import Foundation
import UIKit
import AVFoundation
class CustomCameraController : UIViewController {
    
    var captureSession = AVCaptureSession()
    
    var backCamera : AVCaptureDevice?
    var frontCamera : AVCaptureDevice?
    var currentCamera : AVCaptureDevice?
    
    var photoOutput : AVCapturePhotoOutput?
    
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    
    var cameraCheck = CameraType.front
    var image : UIImage?
    
    var retake = false
    var fail_reg_no = ""
    var cariCnt = 0
    var point = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSeesion()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
    }
    enum CameraType {
        case front
        case back
    }
    //var camera = CameraType.back
    
    @IBAction func cameraButton_TouchUpInside(_ sender: UIButton) {
      //  performSegue(withIdentifier: "showPhoto_Segue", sender: nil)
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cameraState_TouchUpInside(_ sender: UIButton) {
        addVideoInput()
        //reloadCamera()
        
    }
    @IBAction func album_TouchUpInside(_ sender: UIButton) {
        uploadFromAlbum()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto_Segue" {
            let previewVC = segue.destination as! PreviewController
            previewVC.image = self.image
            previewVC.retake = self.retake
            previewVC.cariCnt = self.cariCnt
            previewVC.point = self.point
            previewVC.fail_reg_no = self.fail_reg_no
        }
    }
    
    func setupCaptureSeesion(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    func setupDevice(){
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }else if device.position == AVCaptureDevice.Position.front{
                frontCamera = device
            }
        }
        if cameraCheck == CameraType.front {
            currentCamera = frontCamera
        }else if cameraCheck == CameraType.back{
            currentCamera = backCamera
        }
        
    }
    
    func setupInputOutput(){
        do{
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            if #available(iOS 11.0, *) {
                photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format:[AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                captureSession.addOutput(photoOutput!)
            } else {
                // Fallback on earlier versions
            }
            
        }catch{
            print(error)
        }
        
    }
    func setupPreviewLayer(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        //cameraPreviewLayer?.frame = self.view.frame
        var viewBounds : CGRect = self.view.bounds
        viewBounds.origin.y = 20
        viewBounds.size.height = viewBounds.size.height - 20
        self.cameraPreviewLayer?.frame = viewBounds
        self.view.layer.insertSublayer(cameraPreviewLayer!, at:0)
    }
    func startRunningCaptureSession(){
        captureSession.startRunning()
    }
    
    func addVideoInput() {
        //추가해주기전에 현재 사용중인 input을 제거해준다.
        let removeInput = self.captureSession.inputs.first
        self.captureSession.removeInput(removeInput!)
        
        if cameraCheck ==  CameraType.front  {
            cameraCheck = CameraType.back
            let device: AVCaptureDevice = backCamera!
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }else{
                    print("else..1")
                }
            } catch {
                print(error)
            }
        }else{
            cameraCheck = CameraType.front
            let device: AVCaptureDevice = frontCamera!
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }else{
                    print("else..2")
                }
            } catch {
                print(error)
            }
        }
    }    
    
    func uploadFromAlbum(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        self.present(picker, animated: true)
    }
}

@available(iOS 11.0, *)
extension CustomCameraController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(){
            print(imageData)
            image = UIImage(data:imageData)
            performSegue(withIdentifier: "showPhoto_Segue", sender: nil)
        }
    }
}

extension CustomCameraController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false){
            () in
            print("action cencel")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: false){
            () in
//            guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else{
//                return
//            }
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else{
                return
            }
            guard let imageData = UIImageJPEGRepresentation(image, 0.8)  else{
                print("not JPEG represention of UIIage")
                return
            }
            self.image = UIImage(data:imageData)
            self.performSegue(withIdentifier: "showPhoto_Segue", sender: nil)
        }
    }
}

