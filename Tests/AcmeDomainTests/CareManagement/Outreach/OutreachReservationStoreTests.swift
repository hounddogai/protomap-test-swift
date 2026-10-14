@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachReservationStore = CareManagement.newMemoryOutreachReservationStore()
        let item = CareManagement.newOutreachReservation("code-382", label: "label-314")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
