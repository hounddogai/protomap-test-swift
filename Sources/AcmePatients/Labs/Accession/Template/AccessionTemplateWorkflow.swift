import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession templates through their life cycle and keeps a journal of what it did.
    final class AccessionTemplateCoordinator {
        var store: any AccessionTemplateStore
        var validator: AccessionTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AccessionTemplateStore, validator: AccessionTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionTemplateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionTemplateStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAccessionTemplateCoordinator(_ store: any AccessionTemplateStore, clock: any Kit.Clocks.Clock) -> AccessionTemplateCoordinator {
        return AccessionTemplateCoordinator(
            store: store,
            validator: defaultAccessionTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
