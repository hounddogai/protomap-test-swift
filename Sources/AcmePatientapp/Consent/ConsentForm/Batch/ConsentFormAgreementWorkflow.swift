import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form agreements through their life cycle and keeps a journal of what it did.
    final class ConsentFormAgreementManager {
        var store: any ConsentFormAgreementStore
        var validator: ConsentFormAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormAgreementEngine

        init(store: any ConsentFormAgreementStore, validator: ConsentFormAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormAgreementEngine) {
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
                throw Kit.Failure("consent form agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormAgreementStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormAgreementStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form agreement \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newConsentFormAgreementManager(_ store: any ConsentFormAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormAgreementManager {
        return ConsentFormAgreementManager(
            store: store,
            validator: defaultConsentFormAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormAgreementEngine(flags)
        )
    }
}
