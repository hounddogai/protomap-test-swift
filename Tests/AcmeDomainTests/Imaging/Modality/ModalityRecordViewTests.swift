@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityRecord("code-786", label: "label-835")
        let view = Imaging.toModalityRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityRecordViews([item, item]).count == 2)
    }
}
