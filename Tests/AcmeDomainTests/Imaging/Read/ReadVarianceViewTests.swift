@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadVariance("code-980", name: "name-336")
        let view = Imaging.toReadVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadVarianceViews([item, item]).count == 2)
    }
}
