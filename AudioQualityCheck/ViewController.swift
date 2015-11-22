//
//  ViewController.swift
//  AudioQualityCheck
//
//  Created by YuArai on 2015/11/11.
//  Copyright © 2015年 tenifre. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var avAudioEngineButton: UIButton!
    @IBOutlet weak var avAudioEngineSpeedLabel: UILabel!
    @IBOutlet weak var avAudioEngineSpeedSlider: UISlider!
    
    @IBOutlet weak var avAudioPlayerButton: UIButton!
    @IBOutlet weak var avAudioPlayerSpeedLabel: UILabel!
    @IBOutlet weak var avAudioPlayerSpeedSlider: UISlider!
    
    @IBOutlet weak var audioUnitPlayerButton: UIButton!
    @IBOutlet weak var audioUnitPlayerSpeedLabel: UILabel!
    @IBOutlet weak var audioUnitPlayerSpeedSlider: UISlider!
    
    var audioEngine: AVAudioEngine!
    var audioFile: AVAudioFile!
    var audioPlayerNode: AVAudioPlayerNode!
    var audioUnitTimePitch: AVAudioUnitTimePitch!
    
    var audioPlayer:AVAudioPlayer!
    
    let audioUnitEX = AudioUnitEX()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let url = NSURL(string: NSBundle.mainBundle().pathForResource("sample", ofType: "mp3")!)
            
            /** AVAudioEngine **/
            
            audioEngine = AVAudioEngine()
            audioFile = try AVAudioFile(forReading: url!)
            
            // Prepare AVAudioPlayerNode
            audioPlayerNode = AVAudioPlayerNode()
            audioEngine.attachNode(audioPlayerNode)
            
            // Prepare AVAudioUnitTimePitch
            audioUnitTimePitch = AVAudioUnitTimePitch()
            audioEngine.attachNode(audioUnitTimePitch)

            // Connect Nodes
            audioEngine.connect(audioPlayerNode, to: audioUnitTimePitch, format: audioFile.processingFormat)
            audioEngine.connect(audioUnitTimePitch, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)

            audioEngine.prepare()
            
            /** AVAudioPlayer **/
            audioPlayer = try AVAudioPlayer(contentsOfURL: url!)
            audioPlayer.enableRate = true
            audioPlayer.prepareToPlay()
            
            /** AuiodUnitGraph **/
            audioUnitEX.prepareAudioFile(url)
            audioUnitEX.prepareAUGraph()
        } catch {
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func avAudioEnginePlay() {
        try! audioEngine.start()
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: {
            self.avAudioEnginePlay()
        });
        audioPlayerNode.play()
    }
    
    func avAudioEnginePause() {
        audioEngine.pause()
        audioPlayerNode.pause()
    }
    
    func avAudioPlayerPlay() {
        audioPlayer.play()
    }
    
    func avAudioPlayerPause() {
        audioPlayer.pause()
    }
    
    @IBAction func didTapAVAudioEngineButton(sender: AnyObject) {
        if (audioPlayerNode != nil && audioPlayerNode.playing) {
            self.avAudioEngineButton.setTitle("再生", forState: .Normal)
            avAudioEnginePause()
        } else {
            self.avAudioEngineButton.setTitle("停止", forState: .Normal)
            avAudioEnginePlay()
        }
    }

    @IBAction func didChangedAVAudioEngineSlider(sender: AnyObject) {
        avAudioEngineSpeedLabel?.text = NSString(format: "%.2f", avAudioEngineSpeedSlider.value) as String
        audioUnitTimePitch.rate = avAudioEngineSpeedSlider.value
    }
    
    @IBAction func didTapAVAudioPlayerButton(sender: AnyObject) {
        if (audioPlayer.playing) {
            self.avAudioPlayerButton.setTitle("再生", forState: .Normal)
            avAudioPlayerPause()
        } else {
            self.avAudioPlayerButton.setTitle("停止", forState: .Normal)
            avAudioPlayerPlay()
        }
        
    }
    
    @IBAction func didChangeAVAudioPlayerSlider(sender: AnyObject) {
        avAudioPlayerSpeedLabel?.text = NSString(format: "%.2f", avAudioPlayerSpeedSlider.value) as String
        audioPlayer.rate = avAudioPlayerSpeedSlider.value
    }
    
    @IBAction func didTapAudioUnitPlayerButton(sender: AnyObject) {
        if (audioUnitEX.playing) {
            self.audioUnitPlayerButton.setTitle("再生", forState: .Normal)
            audioUnitEX.stop()
        } else {
            self.audioUnitPlayerButton.setTitle("停止", forState: .Normal)
            audioUnitEX.start()
        }
    }
    
    @IBAction func didChangeAudioUnitSlider(sender: AnyObject) {
        audioUnitPlayerSpeedLabel?.text = NSString(format: "%.2f", audioUnitPlayerSpeedSlider.value) as String
        audioUnitEX.changeRate(audioUnitPlayerSpeedSlider.value)
    }
    
}

