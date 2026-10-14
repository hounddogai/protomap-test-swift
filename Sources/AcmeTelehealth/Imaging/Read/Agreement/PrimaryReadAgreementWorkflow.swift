import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary read agreements through their life cycle and keeps a journal of what it did.
    final class PrimaryReadAgreementManager {
        var store: any PrimaryReadAgreementStore
        var validator: PrimaryReadAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryReadAgreementEngine

        init(store: any PrimaryReadAgreementStore, validator: PrimaryReadAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryReadAgreementEngine) {
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
                throw Kit.Failure("primary read agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryReadAgreementStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary read agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryReadAgreementStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary read agreement \(code) not found")
            }
            let result = engine.price(item)
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

    static func newPrimaryReadAgreementManager(_ store: any PrimaryReadAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryReadAgreementManager {
        return PrimaryReadAgreementManager(
            store: store,
            validator: defaultPrimaryReadAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryReadAgreementEngine(flags)
        )
    }
}
