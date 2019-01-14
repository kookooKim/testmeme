//
//  TakePictureHelpViewController.swift
//  meme
//
//  Created by 이매지니어스 on 2017. 12. 22..
//  Copyright © 2017년 exs. All rights reserved.
//

import Foundation
import UIKit

class TakePictureHelpViewController : UIViewController {
    var image : UIImage?
    var retake = false
    var fail_reg_no = ""
    var cariCnt = 0
    var point = 0
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func takePictureBtn(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "CustomCamera") as? CustomCameraController {
            vc.cariCnt = cariCnt
            vc.point = point
            vc.fail_reg_no = self.fail_reg_no
            vc.retake = self.retake
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func AlbumBtn(_ sender: UIButton) {
        uploadFromAlbum()
    }
    
    func uploadFromAlbum(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto_Segue" {
            let previewVC = segue.destination as! PreviewController
            previewVC.image = self.image
            previewVC.retake = self.retake
            previewVC.cariCnt = self.cariCnt
            previewVC.point = point
            previewVC.fail_reg_no = self.fail_reg_no
        }
    }

}

extension TakePictureHelpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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

