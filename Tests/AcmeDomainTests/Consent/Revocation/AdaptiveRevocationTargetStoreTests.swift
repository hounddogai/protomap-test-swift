@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryAdaptiveRevocationTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.AdaptiveRevocationTargetStore = Consent.newMemoryAdaptiveRevocationTargetStore()
        let item = Consent.newAdaptiveRevocationTarget("code-479", title: "title-346")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
