import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional order set overrides through their life cycle and keeps a journal of what it did.
    final class RegionalOrderSetOverrideDesk {
        var store: any RegionalOrderSetOverrideStore
        var validator: RegionalOrderSetOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalOrderSetOverrideEngine

        init(store: any RegionalOrderSetOverrideStore, validator: RegionalOrderSetOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalOrderSetOverrideEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional order set override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalOrderSetOverrideStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional order set override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalOrderSetOverrideStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional order set override \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRegionalOrderSetOverrideDesk(_ store: any RegionalOrderSetOverrideStore, clock: any Kit.Clocks.Clock) -> RegionalOrderSetOverrideDesk {
        return RegionalOrderSetOverrideDesk(
            store: store,
            validator: defaultRegionalOrderSetOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalOrderSetOverrideEngine()
        )
    }
}
