import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation templates through their life cycle and keeps a journal of what it did.
    final class IsolationTemplateService {
        var store: any IsolationTemplateStore
        var validator: IsolationTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any IsolationTemplateStore, validator: IsolationTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("isolation template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newIsolationTemplateService(_ store: any IsolationTemplateStore, clock: any Kit.Clocks.Clock) -> IsolationTemplateService {
        return IsolationTemplateService(
            store: store,
            validator: defaultIsolationTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
