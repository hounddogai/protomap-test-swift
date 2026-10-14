import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form cycles through their life cycle and keeps a journal of what it did.
    final class ConsentFormCycleManager {
        var store: any ConsentFormCycleStore
        var validator: ConsentFormCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormCycleEngine

        init(store: any ConsentFormCycleStore, validator: ConsentFormCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormCycleEngine) {
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
                throw Kit.Failure("consent form cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form cycle \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newConsentFormCycleManager(_ store: any ConsentFormCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormCycleManager {
        return ConsentFormCycleManager(
            store: store,
            validator: defaultConsentFormCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormCycleEngine(flags)
        )
    }
}
