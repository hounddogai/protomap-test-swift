@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingResultAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingResultAgreementStore = Labs.newMemoryRollingResultAgreementStore()
        let item = Labs.newRollingResultAgreement("code-775", name: "name-718")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
