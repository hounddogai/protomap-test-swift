@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedReferenceRangeAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedReferenceRangeAgreementStore = Labs.newMemoryCappedReferenceRangeAgreementStore()
        let item = Labs.newCappedReferenceRangeAgreement("code-748", name: "name-913")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
