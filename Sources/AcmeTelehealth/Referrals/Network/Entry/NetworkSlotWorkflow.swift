import AcmePlatform
import Foundation

extension Referrals {
    /// Moves network slots through their life cycle and keeps a journal of what it did.
    final class NetworkSlotManager {
        var store: any NetworkSlotStore
        var validator: NetworkSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: NetworkSlotEngine

        init(store: any NetworkSlotStore, validator: NetworkSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: NetworkSlotEngine) {
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
                throw Kit.Failure("network slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(NetworkSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("network slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(NetworkSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("network slot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newNetworkSlotManager(_ store: any NetworkSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> NetworkSlotManager {
        return NetworkSlotManager(
            store: store,
            validator: defaultNetworkSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultNetworkSlotEngine(flags)
        )
    }
}
