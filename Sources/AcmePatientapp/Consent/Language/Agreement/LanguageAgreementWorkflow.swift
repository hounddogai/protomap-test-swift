import AcmePlatform
import Foundation

extension Consent {
    /// Moves language agreements through their life cycle and keeps a journal of what it did.
    final class LanguageAgreementDesk {
        var store: any LanguageAgreementStore
        var validator: LanguageAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageAgreementEngine

        init(store: any LanguageAgreementStore, validator: LanguageAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageAgreementEngine) {
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
                throw Kit.Failure("language agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language agreement \(code) not found")
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

    static func newLanguageAgreementDesk(_ store: any LanguageAgreementStore, clock: any Kit.Clocks.Clock) -> LanguageAgreementDesk {
        return LanguageAgreementDesk(
            store: store,
            validator: defaultLanguageAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageAgreementEngine()
        )
    }
}
