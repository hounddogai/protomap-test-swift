@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityPolicy("code-630", name: "name-754")
        let view = Imaging.toModalityPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityPolicyViews([item, item]).count == 2)
    }
}
