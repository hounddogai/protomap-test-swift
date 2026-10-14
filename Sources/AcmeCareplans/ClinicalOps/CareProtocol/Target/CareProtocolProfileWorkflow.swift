import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol profiles through their life cycle and keeps a journal of what it did.
    final class CareProtocolProfileCoordinator {
        var store: any CareProtocolProfileStore
        var validator: CareProtocolProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolProfileStore, validator: CareProtocolProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolProfileStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolProfileStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newCareProtocolProfileCoordinator(_ store: any CareProtocolProfileStore, clock: any Kit.Clocks.Clock) -> CareProtocolProfileCoordinator {
        return CareProtocolProfileCoordinator(
            store: store,
            validator: defaultCareProtocolProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
