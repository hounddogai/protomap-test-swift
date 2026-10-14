import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap proposals through their life cycle and keeps a journal of what it did.
    final class CareGapProposalDesk {
        var store: any CareGapProposalStore
        var validator: CareGapProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapProposalEngine

        init(store: any CareGapProposalStore, validator: CareGapProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapProposalEngine) {
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
                throw Kit.Failure("care gap proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapProposalStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapProposalStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap proposal \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCareGapProposalDesk(_ store: any CareGapProposalStore, clock: any Kit.Clocks.Clock) -> CareGapProposalDesk {
        return CareGapProposalDesk(
            store: store,
            validator: defaultCareGapProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapProposalEngine()
        )
    }
}
