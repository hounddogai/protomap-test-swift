import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict charge groups through their life cycle and keeps a journal of what it did.
    final class StrictChargeGroupService {
        var store: any StrictChargeGroupStore
        var validator: StrictChargeGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictChargeGroupEngine

        init(store: any StrictChargeGroupStore, validator: StrictChargeGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictChargeGroupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict charge group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictChargeGroupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict charge group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictChargeGroupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict charge group \(code) not found")
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

    static func newStrictChargeGroupService(_ store: any StrictChargeGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictChargeGroupService {
        return StrictChargeGroupService(
            store: store,
            validator: defaultStrictChargeGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictChargeGroupEngine(flags)
        )
    }
}
