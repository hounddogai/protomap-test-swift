import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped charge groups through their life cycle and keeps a journal of what it did.
    final class CappedChargeGroupDesk {
        var store: any CappedChargeGroupStore
        var validator: CappedChargeGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedChargeGroupEngine

        init(store: any CappedChargeGroupStore, validator: CappedChargeGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedChargeGroupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedChargeGroupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedChargeGroupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge group \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newCappedChargeGroupDesk(_ store: any CappedChargeGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedChargeGroupDesk {
        return CappedChargeGroupDesk(
            store: store,
            validator: defaultCappedChargeGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedChargeGroupEngine(flags)
        )
    }
}
