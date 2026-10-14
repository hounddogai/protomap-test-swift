import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global priority agreements through their life cycle and keeps a journal of what it did.
    final class GlobalPriorityAgreementService {
        var store: any GlobalPriorityAgreementStore
        var validator: GlobalPriorityAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalPriorityAgreementStore, validator: GlobalPriorityAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global priority agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalPriorityAgreementStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global priority agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalPriorityAgreementStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newGlobalPriorityAgreementService(_ store: any GlobalPriorityAgreementStore, clock: any Kit.Clocks.Clock) -> GlobalPriorityAgreementService {
        return GlobalPriorityAgreementService(
            store: store,
            validator: defaultGlobalPriorityAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
