@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadException("code-536", label: "label-559")
        let view = Imaging.toReadExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadExceptionViews([item, item]).count == 2)
    }
}
