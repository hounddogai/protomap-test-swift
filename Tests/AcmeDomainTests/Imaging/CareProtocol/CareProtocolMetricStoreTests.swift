@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolMetricStore = Imaging.newMemoryCareProtocolMetricStore()
        let item = Imaging.newCareProtocolMetric("code-656", name: "name-223")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
