import AcmePlatform
import Foundation

extension Labs {
    /// Moves legacy accession proposals through their life cycle and keeps a journal of what it did.
    final class LegacyAccessionProposalWorkflow {
        var store: any LegacyAccessionProposalStore
        var validator: LegacyAccessionProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyAccessionProposalEngine

        init(store: any LegacyAccessionProposalStore, validator: LegacyAccessionProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyAccessionProposalEngine) {
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
                throw Kit.Failure("legacy accession proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyAccessionProposalStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy accession proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyAccessionProposalStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy accession proposal \(code) not found")
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

    static func newLegacyAccessionProposalWorkflow(_ store: any LegacyAccessionProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyAccessionProposalWorkflow {
        return LegacyAccessionProposalWorkflow(
            store: store,
            validator: defaultLegacyAccessionProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyAccessionProposalEngine(flags)
        )
    }
}
