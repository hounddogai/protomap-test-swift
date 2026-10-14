import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual substitution digests through their life cycle and keeps a journal of what it did.
    final class ManualSubstitutionDigestService {
        var store: any ManualSubstitutionDigestStore
        var validator: ManualSubstitutionDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualSubstitutionDigestEngine

        init(store: any ManualSubstitutionDigestStore, validator: ManualSubstitutionDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualSubstitutionDigestEngine) {
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
                throw Kit.Failure("manual substitution digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualSubstitutionDigestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual substitution digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualSubstitutionDigestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual substitution digest \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newManualSubstitutionDigestService(_ store: any ManualSubstitutionDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualSubstitutionDigestService {
        return ManualSubstitutionDigestService(
            store: store,
            validator: defaultManualSubstitutionDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualSubstitutionDigestEngine(flags)
        )
    }
}
