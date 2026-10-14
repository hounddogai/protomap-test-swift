@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolException("code-208", name: "name-627")
        let view = Imaging.toCareProtocolExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolExceptionViews([item, item]).count == 2)
    }
}
