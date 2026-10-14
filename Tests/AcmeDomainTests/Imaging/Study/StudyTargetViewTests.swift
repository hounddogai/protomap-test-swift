@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyTarget("code-173", label: "label-386")
        let view = Imaging.toStudyTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyTargetViews([item, item]).count == 2)
    }
}
