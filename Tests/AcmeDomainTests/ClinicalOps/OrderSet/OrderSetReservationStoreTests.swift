@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetReservationStore = ClinicalOps.newMemoryOrderSetReservationStore()
        let item = ClinicalOps.newOrderSetReservation("code-624", label: "label-564")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
