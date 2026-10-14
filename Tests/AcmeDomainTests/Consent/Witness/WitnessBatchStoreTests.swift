@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessBatchStore = Consent.newMemoryWitnessBatchStore()
        let item = Consent.newWitnessBatch("code-541", label: "label-902")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
