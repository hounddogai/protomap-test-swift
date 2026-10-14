import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure agreements through their life cycle and keeps a journal of what it did.
    final class DisclosureAgreementDesk {
        var store: any DisclosureAgreementStore
        var validator: DisclosureAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureAgreementEngine

        init(store: any DisclosureAgreementStore, validator: DisclosureAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureAgreementEngine) {
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
                throw Kit.Failure("disclosure agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureAgreementStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureAgreementStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure agreement \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newDisclosureAgreementDesk(_ store: any DisclosureAgreementStore, clock: any Kit.Clocks.Clock) -> DisclosureAgreementDesk {
        return DisclosureAgreementDesk(
            store: store,
            validator: defaultDisclosureAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureAgreementEngine()
        )
    }
}
