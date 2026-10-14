import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy formulary groups through their life cycle and keeps a journal of what it did.
    final class LegacyFormularyGroupDesk {
        var store: any LegacyFormularyGroupStore
        var validator: LegacyFormularyGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyFormularyGroupEngine

        init(store: any LegacyFormularyGroupStore, validator: LegacyFormularyGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyFormularyGroupEngine) {
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
                throw Kit.Failure("legacy formulary group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyFormularyGroupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy formulary group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyFormularyGroupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy formulary group \(code) not found")
            }
            let result = engine.run(item)
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

    static func newLegacyFormularyGroupDesk(_ store: any LegacyFormularyGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyFormularyGroupDesk {
        return LegacyFormularyGroupDesk(
            store: store,
            validator: defaultLegacyFormularyGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyFormularyGroupEngine(flags)
        )
    }
}
