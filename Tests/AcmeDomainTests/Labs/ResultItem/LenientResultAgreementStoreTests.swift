@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientResultAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientResultAgreementStore = Labs.newMemoryLenientResultAgreementStore()
        let item = Labs.newLenientResultAgreement("code-582", title: "title-990")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
