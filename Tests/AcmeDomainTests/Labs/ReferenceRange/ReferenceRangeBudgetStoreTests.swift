@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeBudgetStore = Labs.newMemoryReferenceRangeBudgetStore()
        let item = Labs.newReferenceRangeBudget("code-738", label: "label-22")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
