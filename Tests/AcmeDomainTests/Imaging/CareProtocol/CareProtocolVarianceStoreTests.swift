@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolVarianceStore = Imaging.newMemoryCareProtocolVarianceStore()
        let item = Imaging.newCareProtocolVariance("code-87", title: "title-694")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
