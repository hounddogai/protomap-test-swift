import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual network cycles through their life cycle and keeps a journal of what it did.
    final class ManualNetworkCycleManager {
        var store: any ManualNetworkCycleStore
        var validator: ManualNetworkCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualNetworkCycleEngine

        init(store: any ManualNetworkCycleStore, validator: ManualNetworkCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualNetworkCycleEngine) {
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
                throw Kit.Failure("manual network cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualNetworkCycleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualNetworkCycleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network cycle \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newManualNetworkCycleManager(_ store: any ManualNetworkCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualNetworkCycleManager {
        return ManualNetworkCycleManager(
            store: store,
            validator: defaultManualNetworkCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualNetworkCycleEngine(flags)
        )
    }
}
