@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyRecord("code-714", label: "label-32")
        let view = Imaging.toStudyRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyRecordViews([item, item]).count == 2)
    }
}
