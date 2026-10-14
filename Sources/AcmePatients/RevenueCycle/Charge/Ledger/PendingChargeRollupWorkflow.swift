import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending charge rollups through their life cycle and keeps a journal of what it did.
    final class PendingChargeRollupService {
        var store: any PendingChargeRollupStore
        var validator: PendingChargeRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingChargeRollupEngine

        init(store: any PendingChargeRollupStore, validator: PendingChargeRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingChargeRollupEngine) {
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
                throw Kit.Failure("pending charge rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingChargeRollupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingChargeRollupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge rollup \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPendingChargeRollupService(_ store: any PendingChargeRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingChargeRollupService {
        return PendingChargeRollupService(
            store: store,
            validator: defaultPendingChargeRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingChargeRollupEngine(flags)
        )
    }
}
