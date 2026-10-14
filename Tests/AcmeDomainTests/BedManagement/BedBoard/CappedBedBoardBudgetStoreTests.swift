@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedBedBoardBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedBedBoardBudgetStore = BedManagement.newMemoryCappedBedBoardBudgetStore()
        let item = BedManagement.newCappedBedBoardBudget("code-643", label: "label-977")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
