@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionAgreementStore = Labs.newMemoryAccessionAgreementStore()
        let item = Labs.newAccessionAgreement("code-544", title: "title-125")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
