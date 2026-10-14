@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolVariance("code-87", title: "title-694")
        let view = Imaging.toCareProtocolVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolVarianceViews([item, item]).count == 2)
    }
}
