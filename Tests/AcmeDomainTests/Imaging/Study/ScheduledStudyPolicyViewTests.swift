@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledStudyPolicy("code-722", label: "label-341")
        let view = Imaging.toScheduledStudyPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledStudyPolicyViews([item, item]).count == 2)
    }
}
