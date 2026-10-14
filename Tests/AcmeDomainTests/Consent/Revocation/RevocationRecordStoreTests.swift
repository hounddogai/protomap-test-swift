@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationRecordStore = Consent.newMemoryRevocationRecordStore()
        let item = Consent.newRevocationRecord("code-847", label: "label-832")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
