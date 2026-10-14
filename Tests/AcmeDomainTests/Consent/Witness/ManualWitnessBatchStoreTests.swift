@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualWitnessBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualWitnessBatchStore = Consent.newMemoryManualWitnessBatchStore()
        let item = Consent.newManualWitnessBatch("code-453", name: "name-715")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
