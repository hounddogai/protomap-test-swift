@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramAgreementStore = CareManagement.newMemoryProgramAgreementStore()
        let item = CareManagement.newProgramAgreement("code-281", label: "label-169")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
