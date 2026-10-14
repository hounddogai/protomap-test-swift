@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedPriorityProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newBatchedPriorityProfile("code-296", title: "title-995")
        let view = Imaging.toBatchedPriorityProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toBatchedPriorityProfileViews([item, item]).count == 2)
    }
}
