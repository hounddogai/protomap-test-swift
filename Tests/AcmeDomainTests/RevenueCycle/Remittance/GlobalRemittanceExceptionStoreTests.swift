@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalRemittanceExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalRemittanceExceptionStore = RevenueCycle.newMemoryGlobalRemittanceExceptionStore()
        let item = RevenueCycle.newGlobalRemittanceException("code-999", name: "name-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
