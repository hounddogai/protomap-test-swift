@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistBatch("code-614", label: "label-489")
        let view = Imaging.toWorklistBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistBatchViews([item, item]).count == 2)
    }
}
