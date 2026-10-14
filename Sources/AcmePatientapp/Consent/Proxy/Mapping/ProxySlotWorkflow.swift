import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy slots through their life cycle and keeps a journal of what it did.
    final class ProxySlotCoordinator {
        var store: any ProxySlotStore
        var validator: ProxySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxySlotEngine

        init(store: any ProxySlotStore, validator: ProxySlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxySlotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxySlotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxySlotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy slot \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newProxySlotCoordinator(_ store: any ProxySlotStore, clock: any Kit.Clocks.Clock) -> ProxySlotCoordinator {
        return ProxySlotCoordinator(
            store: store,
            validator: defaultProxySlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxySlotEngine()
        )
    }
}
