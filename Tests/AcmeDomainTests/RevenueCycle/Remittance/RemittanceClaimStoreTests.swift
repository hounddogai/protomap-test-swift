@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceClaimStore = RevenueCycle.newMemoryRemittanceClaimStore()
        let item = RevenueCycle.newRemittanceClaim("code-217", label: "label-820")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
