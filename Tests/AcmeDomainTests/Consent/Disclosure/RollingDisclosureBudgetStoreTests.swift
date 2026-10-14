@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingDisclosureBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingDisclosureBudgetStore = Consent.newMemoryRollingDisclosureBudgetStore()
        let item = Consent.newRollingDisclosureBudget("code-928", label: "label-645")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
