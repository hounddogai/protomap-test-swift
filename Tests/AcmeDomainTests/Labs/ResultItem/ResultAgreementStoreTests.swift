@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultAgreementStore = Labs.newMemoryResultAgreementStore()
        let item = Labs.newResultAgreement("code-493", title: "title-823")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
