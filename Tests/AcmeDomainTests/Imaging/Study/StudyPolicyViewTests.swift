@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyPolicy("code-769", title: "title-930")
        let view = Imaging.toStudyPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyPolicyViews([item, item]).count == 2)
    }
}
